import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves capped charge assignments through their life cycle and keeps a journal of what it did.
    final class CappedChargeAssignmentManager {
        var store: any CappedChargeAssignmentStore
        var validator: CappedChargeAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedChargeAssignmentEngine

        init(store: any CappedChargeAssignmentStore, validator: CappedChargeAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedChargeAssignmentEngine) {
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
                throw Kit.Failure("capped charge assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedChargeAssignmentStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped charge assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedChargeAssignmentStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped charge assignment \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newCappedChargeAssignmentManager(_ store: any CappedChargeAssignmentStore, clock: any Kit.Clocks.Clock) -> CappedChargeAssignmentManager {
        return CappedChargeAssignmentManager(
            store: store,
            validator: defaultCappedChargeAssignmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedChargeAssignmentEngine()
        )
    }
}
