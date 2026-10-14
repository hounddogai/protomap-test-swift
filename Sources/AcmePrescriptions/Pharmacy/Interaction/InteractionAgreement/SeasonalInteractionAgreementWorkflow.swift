import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves seasonal interaction agreements through their life cycle and keeps a journal of what it did.
    final class SeasonalInteractionAgreementManager {
        var store: any SeasonalInteractionAgreementStore
        var validator: SeasonalInteractionAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalInteractionAgreementEngine

        init(store: any SeasonalInteractionAgreementStore, validator: SeasonalInteractionAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalInteractionAgreementEngine) {
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
                throw Kit.Failure("seasonal interaction agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalInteractionAgreementStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal interaction agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalInteractionAgreementStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal interaction agreement \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newSeasonalInteractionAgreementManager(_ store: any SeasonalInteractionAgreementStore, clock: any Kit.Clocks.Clock) -> SeasonalInteractionAgreementManager {
        return SeasonalInteractionAgreementManager(
            store: store,
            validator: defaultSeasonalInteractionAgreementValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalInteractionAgreementEngine()
        )
    }
}
