import AcmePlatform
import Foundation

extension Imaging {
    /// Moves priority groups through their life cycle and keeps a journal of what it did.
    final class PriorityGroupManager {
        var store: any PriorityGroupStore
        var validator: PriorityGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PriorityGroupEngine

        init(store: any PriorityGroupStore, validator: PriorityGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PriorityGroupEngine) {
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
                throw Kit.Failure("priority group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PriorityGroupStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("priority group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PriorityGroupStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("priority group \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newPriorityGroupManager(_ store: any PriorityGroupStore, clock: any Kit.Clocks.Clock) -> PriorityGroupManager {
        return PriorityGroupManager(
            store: store,
            validator: defaultPriorityGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultPriorityGroupEngine()
        )
    }
}
