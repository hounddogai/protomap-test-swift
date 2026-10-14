import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves capped risk score windows through their life cycle and keeps a journal of what it did.
    final class CappedRiskScoreWindowService {
        var store: any CappedRiskScoreWindowStore
        var validator: CappedRiskScoreWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedRiskScoreWindowEngine

        init(store: any CappedRiskScoreWindowStore, validator: CappedRiskScoreWindowValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedRiskScoreWindowEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped risk score window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedRiskScoreWindowStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped risk score window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedRiskScoreWindowStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped risk score window \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newCappedRiskScoreWindowService(_ store: any CappedRiskScoreWindowStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CappedRiskScoreWindowService {
        return CappedRiskScoreWindowService(
            store: store,
            validator: defaultCappedRiskScoreWindowValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedRiskScoreWindowEngine(flags)
        )
    }
}
