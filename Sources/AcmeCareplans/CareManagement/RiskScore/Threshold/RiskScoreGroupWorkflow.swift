import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves risk score groups through their life cycle and keeps a journal of what it did.
    final class RiskScoreGroupService {
        var store: any RiskScoreGroupStore
        var validator: RiskScoreGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RiskScoreGroupStore, validator: RiskScoreGroupValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("risk score group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RiskScoreGroupStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("risk score group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RiskScoreGroupStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newRiskScoreGroupService(_ store: any RiskScoreGroupStore, clock: any Kit.Clocks.Clock) -> RiskScoreGroupService {
        return RiskScoreGroupService(
            store: store,
            validator: defaultRiskScoreGroupValidator(),
            clock: clock,
            journal: []
        )
    }
}
