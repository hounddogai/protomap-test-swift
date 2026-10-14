import AcmePlatform
import Foundation

extension Referrals {
    /// Moves closure allocations through their life cycle and keeps a journal of what it did.
    final class ClosureAllocationService {
        var store: any ClosureAllocationStore
        var validator: ClosureAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ClosureAllocationEngine

        init(store: any ClosureAllocationStore, validator: ClosureAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ClosureAllocationEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClosureAllocationStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClosureAllocationStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure allocation \(code) not found")
            }
            let result = engine.run(item)
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

    static func newClosureAllocationService(_ store: any ClosureAllocationStore, clock: any Kit.Clocks.Clock) -> ClosureAllocationService {
        return ClosureAllocationService(
            store: store,
            validator: defaultClosureAllocationValidator(),
            clock: clock,
            journal: [],
            engine: defaultClosureAllocationEngine()
        )
    }
}
