import AcmePlatform
import Foundation

extension Staffing {
    /// Moves float pool claims through their life cycle and keeps a journal of what it did.
    final class FloatPoolClaimCoordinator {
        var store: any FloatPoolClaimStore
        var validator: FloatPoolClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FloatPoolClaimStore, validator: FloatPoolClaimValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("float pool claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FloatPoolClaimStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("float pool claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FloatPoolClaimStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newFloatPoolClaimCoordinator(_ store: any FloatPoolClaimStore, clock: any Kit.Clocks.Clock) -> FloatPoolClaimCoordinator {
        return FloatPoolClaimCoordinator(
            store: store,
            validator: defaultFloatPoolClaimValidator(),
            clock: clock,
            journal: []
        )
    }
}
