import AcmePlatform
import Foundation

extension Referrals {
    /// Moves eligibility bundles through their life cycle and keeps a journal of what it did.
    final class EligibilityBundleService {
        var store: any EligibilityBundleStore
        var validator: EligibilityBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: EligibilityBundleEngine

        init(store: any EligibilityBundleStore, validator: EligibilityBundleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: EligibilityBundleEngine) {
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
                throw Kit.Failure("eligibility bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(EligibilityBundleStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("eligibility bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(EligibilityBundleStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("eligibility bundle \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newEligibilityBundleService(_ store: any EligibilityBundleStore, clock: any Kit.Clocks.Clock) -> EligibilityBundleService {
        return EligibilityBundleService(
            store: store,
            validator: defaultEligibilityBundleValidator(),
            clock: clock,
            journal: [],
            engine: defaultEligibilityBundleEngine()
        )
    }
}
