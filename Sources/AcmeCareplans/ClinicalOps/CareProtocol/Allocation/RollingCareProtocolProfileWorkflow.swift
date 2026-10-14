import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves rolling care protocol profiles through their life cycle and keeps a journal of what it did.
    final class RollingCareProtocolProfileCoordinator {
        var store: any RollingCareProtocolProfileStore
        var validator: RollingCareProtocolProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RollingCareProtocolProfileStore, validator: RollingCareProtocolProfileValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("rolling care protocol profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingCareProtocolProfileStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling care protocol profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingCareProtocolProfileStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newRollingCareProtocolProfileCoordinator(_ store: any RollingCareProtocolProfileStore, clock: any Kit.Clocks.Clock) -> RollingCareProtocolProfileCoordinator {
        return RollingCareProtocolProfileCoordinator(
            store: store,
            validator: defaultRollingCareProtocolProfileValidator(),
            clock: clock,
            journal: []
        )
    }
}
