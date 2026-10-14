import AcmePlatform
import Foundation

extension Staffing {
    /// Moves pending skill mix requests through their life cycle and keeps a journal of what it did.
    final class PendingSkillMixRequestDesk {
        var store: any PendingSkillMixRequestStore
        var validator: PendingSkillMixRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PendingSkillMixRequestStore, validator: PendingSkillMixRequestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("pending skill mix request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingSkillMixRequestStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending skill mix request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingSkillMixRequestStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newPendingSkillMixRequestDesk(_ store: any PendingSkillMixRequestStore, clock: any Kit.Clocks.Clock) -> PendingSkillMixRequestDesk {
        return PendingSkillMixRequestDesk(
            store: store,
            validator: defaultPendingSkillMixRequestValidator(),
            clock: clock,
            journal: []
        )
    }
}
