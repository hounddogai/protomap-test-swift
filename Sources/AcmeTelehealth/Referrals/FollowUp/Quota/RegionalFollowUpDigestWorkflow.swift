import AcmePlatform
import Foundation

extension Referrals {
    /// Moves regional follow up digests through their life cycle and keeps a journal of what it did.
    final class RegionalFollowUpDigestService {
        var store: any RegionalFollowUpDigestStore
        var validator: RegionalFollowUpDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalFollowUpDigestEngine

        init(store: any RegionalFollowUpDigestStore, validator: RegionalFollowUpDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalFollowUpDigestEngine) {
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
                throw Kit.Failure("regional follow up digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalFollowUpDigestStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional follow up digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalFollowUpDigestStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional follow up digest \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newRegionalFollowUpDigestService(_ store: any RegionalFollowUpDigestStore, clock: any Kit.Clocks.Clock) -> RegionalFollowUpDigestService {
        return RegionalFollowUpDigestService(
            store: store,
            validator: defaultRegionalFollowUpDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalFollowUpDigestEngine()
        )
    }
}
