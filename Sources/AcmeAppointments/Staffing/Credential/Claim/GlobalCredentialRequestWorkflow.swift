import AcmePlatform
import Foundation

extension Staffing {
    /// Moves global credential requests through their life cycle and keeps a journal of what it did.
    final class GlobalCredentialRequestCoordinator {
        var store: any GlobalCredentialRequestStore
        var validator: GlobalCredentialRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any GlobalCredentialRequestStore, validator: GlobalCredentialRequestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("global credential request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalCredentialRequestStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global credential request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalCredentialRequestStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newGlobalCredentialRequestCoordinator(_ store: any GlobalCredentialRequestStore, clock: any Kit.Clocks.Clock) -> GlobalCredentialRequestCoordinator {
        return GlobalCredentialRequestCoordinator(
            store: store,
            validator: defaultGlobalCredentialRequestValidator(),
            clock: clock,
            journal: []
        )
    }
}
