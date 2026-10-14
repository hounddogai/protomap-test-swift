import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves remittance plans through their life cycle and keeps a journal of what it did.
    final class RemittancePlanManager {
        var store: any RemittancePlanStore
        var validator: RemittancePlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RemittancePlanEngine

        init(store: any RemittancePlanStore, validator: RemittancePlanValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RemittancePlanEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RemittancePlanStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RemittancePlanStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance plan \(code) not found")
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

    static func newRemittancePlanManager(_ store: any RemittancePlanStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RemittancePlanManager {
        return RemittancePlanManager(
            store: store,
            validator: defaultRemittancePlanValidator(),
            clock: clock,
            journal: [],
            engine: defaultRemittancePlanEngine(flags)
        )
    }
}
