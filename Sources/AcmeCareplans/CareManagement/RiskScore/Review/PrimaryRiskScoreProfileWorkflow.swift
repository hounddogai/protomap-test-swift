import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves primary risk score profiles through their life cycle and keeps a journal of what it did.
    final class PrimaryRiskScoreProfileService {
        var store: any PrimaryRiskScoreProfileStore
        var validator: PrimaryRiskScoreProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PrimaryRiskScoreProfileStore, validator: PrimaryRiskScoreProfileValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary risk score profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryRiskScoreProfileStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary risk score profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryRiskScoreProfileStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newPrimaryRiskScoreProfileService(_ store: any PrimaryRiskScoreProfileStore, clock: any Kit.Clocks.Clock) -> PrimaryRiskScoreProfileService {
        return PrimaryRiskScoreProfileService(
            store: store,
            validator: defaultPrimaryRiskScoreProfileValidator(),
            clock: clock,
            journal: []
        )
    }
}
