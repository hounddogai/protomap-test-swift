import AcmePlatform
import Foundation

extension Referrals {
    /// Moves primary eligibility quotas through their life cycle and keeps a journal of what it did.
    final class PrimaryEligibilityQuotaService {
        var store: any PrimaryEligibilityQuotaStore
        var validator: PrimaryEligibilityQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryEligibilityQuotaEngine

        init(store: any PrimaryEligibilityQuotaStore, validator: PrimaryEligibilityQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryEligibilityQuotaEngine) {
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
                throw Kit.Failure("primary eligibility quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryEligibilityQuotaStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary eligibility quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryEligibilityQuotaStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary eligibility quota \(code) not found")
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

    static func newPrimaryEligibilityQuotaService(_ store: any PrimaryEligibilityQuotaStore, clock: any Kit.Clocks.Clock) -> PrimaryEligibilityQuotaService {
        return PrimaryEligibilityQuotaService(
            store: store,
            validator: defaultPrimaryEligibilityQuotaValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryEligibilityQuotaEngine()
        )
    }
}
