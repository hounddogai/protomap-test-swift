import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves seasonal authorization agreements through their life cycle and keeps a journal of what it did.
    final class SeasonalAuthorizationAgreementManager {
        var store: any SeasonalAuthorizationAgreementStore
        var validator: SeasonalAuthorizationAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalAuthorizationAgreementEngine

        init(store: any SeasonalAuthorizationAgreementStore, validator: SeasonalAuthorizationAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalAuthorizationAgreementEngine) {
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
                throw Kit.Failure("seasonal authorization agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalAuthorizationAgreementStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal authorization agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalAuthorizationAgreementStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal authorization agreement \(code) not found")
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
                if item.endsAt > cutoff {
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

    static func newSeasonalAuthorizationAgreementManager(_ store: any SeasonalAuthorizationAgreementStore, clock: any Kit.Clocks.Clock) -> SeasonalAuthorizationAgreementManager {
        return SeasonalAuthorizationAgreementManager(
            store: store,
            validator: defaultSeasonalAuthorizationAgreementValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalAuthorizationAgreementEngine()
        )
    }
}
