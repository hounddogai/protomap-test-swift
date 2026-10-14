import AcmePlatform
import Foundation

extension Consent {
    /// Moves rolling consent form targets through their life cycle and keeps a journal of what it did.
    final class RollingConsentFormTargetService {
        var store: any RollingConsentFormTargetStore
        var validator: RollingConsentFormTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RollingConsentFormTargetStore, validator: RollingConsentFormTargetValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling consent form target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingConsentFormTargetStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling consent form target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingConsentFormTargetStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newRollingConsentFormTargetService(_ store: any RollingConsentFormTargetStore, clock: any Kit.Clocks.Clock) -> RollingConsentFormTargetService {
        return RollingConsentFormTargetService(
            store: store,
            validator: defaultRollingConsentFormTargetValidator(),
            clock: clock,
            journal: []
        )
    }
}
