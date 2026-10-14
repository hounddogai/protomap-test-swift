import AcmePlatform
import Foundation

extension Imaging {
    /// Moves read allocations through their life cycle and keeps a journal of what it did.
    final class ReadAllocationCoordinator {
        var store: any ReadAllocationStore
        var validator: ReadAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ReadAllocationEngine

        init(store: any ReadAllocationStore, validator: ReadAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ReadAllocationEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("read allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReadAllocationStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("read allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReadAllocationStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("read allocation \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newReadAllocationCoordinator(_ store: any ReadAllocationStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ReadAllocationCoordinator {
        return ReadAllocationCoordinator(
            store: store,
            validator: defaultReadAllocationValidator(),
            clock: clock,
            journal: [],
            engine: defaultReadAllocationEngine(flags)
        )
    }
}
