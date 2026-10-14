import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves lenient claim profiles through their life cycle and keeps a journal of what it did.
    final class LenientClaimProfileWorkflow {
        var store: any LenientClaimProfileStore
        var validator: LenientClaimProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LenientClaimProfileStore, validator: LenientClaimProfileValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient claim profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientClaimProfileStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient claim profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientClaimProfileStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newLenientClaimProfileWorkflow(_ store: any LenientClaimProfileStore, clock: any Kit.Clocks.Clock) -> LenientClaimProfileWorkflow {
        return LenientClaimProfileWorkflow(
            store: store,
            validator: defaultLenientClaimProfileValidator(),
            clock: clock,
            journal: []
        )
    }
}
