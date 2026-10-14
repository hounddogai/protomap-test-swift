import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves charge baselines through their life cycle and keeps a journal of what it did.
    final class ChargeBaselineService {
        var store: any ChargeBaselineStore
        var validator: ChargeBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ChargeBaselineEngine

        init(store: any ChargeBaselineStore, validator: ChargeBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ChargeBaselineEngine) {
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
                throw Kit.Failure("charge baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ChargeBaselineStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("charge baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ChargeBaselineStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("charge baseline \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newChargeBaselineService(_ store: any ChargeBaselineStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ChargeBaselineService {
        return ChargeBaselineService(
            store: store,
            validator: defaultChargeBaselineValidator(),
            clock: clock,
            journal: [],
            engine: defaultChargeBaselineEngine(flags)
        )
    }
}
