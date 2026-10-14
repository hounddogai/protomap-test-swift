import AcmePlatform
import Foundation

extension Consent {
    /// Moves pending disclosure claims through their life cycle and keeps a journal of what it did.
    final class PendingDisclosureClaimManager {
        var store: any PendingDisclosureClaimStore
        var validator: PendingDisclosureClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PendingDisclosureClaimStore, validator: PendingDisclosureClaimValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("pending disclosure claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingDisclosureClaimStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending disclosure claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingDisclosureClaimStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newPendingDisclosureClaimManager(_ store: any PendingDisclosureClaimStore, clock: any Kit.Clocks.Clock) -> PendingDisclosureClaimManager {
        return PendingDisclosureClaimManager(
            store: store,
            validator: defaultPendingDisclosureClaimValidator(),
            clock: clock,
            journal: []
        )
    }
}
