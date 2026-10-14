import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves weighted risk score templates through their life cycle and keeps a journal of what it did.
    final class WeightedRiskScoreTemplateService {
        var store: any WeightedRiskScoreTemplateStore
        var validator: WeightedRiskScoreTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WeightedRiskScoreTemplateStore, validator: WeightedRiskScoreTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted risk score template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedRiskScoreTemplateStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted risk score template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedRiskScoreTemplateStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newWeightedRiskScoreTemplateService(_ store: any WeightedRiskScoreTemplateStore, clock: any Kit.Clocks.Clock) -> WeightedRiskScoreTemplateService {
        return WeightedRiskScoreTemplateService(
            store: store,
            validator: defaultWeightedRiskScoreTemplateValidator(),
            clock: clock,
            journal: []
        )
    }
}
