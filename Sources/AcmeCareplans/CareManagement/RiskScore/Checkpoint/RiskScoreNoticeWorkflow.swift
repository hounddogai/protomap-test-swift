import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves risk score notices through their life cycle and keeps a journal of what it did.
    final class RiskScoreNoticeManager {
        var store: any RiskScoreNoticeStore
        var validator: RiskScoreNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RiskScoreNoticeEngine

        init(store: any RiskScoreNoticeStore, validator: RiskScoreNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RiskScoreNoticeEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("risk score notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RiskScoreNoticeStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("risk score notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RiskScoreNoticeStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("risk score notice \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newRiskScoreNoticeManager(_ store: any RiskScoreNoticeStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RiskScoreNoticeManager {
        return RiskScoreNoticeManager(
            store: store,
            validator: defaultRiskScoreNoticeValidator(),
            clock: clock,
            journal: [],
            engine: defaultRiskScoreNoticeEngine(flags)
        )
    }
}
