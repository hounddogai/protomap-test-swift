import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves seasonal order set agreements through their life cycle and keeps a journal of what it did.
    final class SeasonalOrderSetAgreementService {
        var store: any SeasonalOrderSetAgreementStore
        var validator: SeasonalOrderSetAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalOrderSetAgreementEngine

        init(store: any SeasonalOrderSetAgreementStore, validator: SeasonalOrderSetAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalOrderSetAgreementEngine) {
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
                throw Kit.Failure("seasonal order set agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalOrderSetAgreementStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal order set agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalOrderSetAgreementStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal order set agreement \(code) not found")
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

    static func newSeasonalOrderSetAgreementService(_ store: any SeasonalOrderSetAgreementStore, clock: any Kit.Clocks.Clock) -> SeasonalOrderSetAgreementService {
        return SeasonalOrderSetAgreementService(
            store: store,
            validator: defaultSeasonalOrderSetAgreementValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalOrderSetAgreementEngine()
        )
    }
}
