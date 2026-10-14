import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves risk score digests through their life cycle and keeps a journal of what it did.
    final class RiskScoreDigestDesk {
        var store: any RiskScoreDigestStore
        var validator: RiskScoreDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RiskScoreDigestStore, validator: RiskScoreDigestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("risk score digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RiskScoreDigestStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("risk score digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RiskScoreDigestStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newRiskScoreDigestDesk(_ store: any RiskScoreDigestStore, clock: any Kit.Clocks.Clock) -> RiskScoreDigestDesk {
        return RiskScoreDigestDesk(
            store: store,
            validator: defaultRiskScoreDigestValidator(),
            clock: clock,
            journal: []
        )
    }
}
