import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves claim notices through their life cycle and keeps a journal of what it did.
    final class ClaimNoticeWorkflow {
        var store: any ClaimNoticeStore
        var validator: ClaimNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ClaimNoticeStore, validator: ClaimNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("claim notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClaimNoticeStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClaimNoticeStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newClaimNoticeWorkflow(_ store: any ClaimNoticeStore, clock: any Kit.Clocks.Clock) -> ClaimNoticeWorkflow {
        return ClaimNoticeWorkflow(store: store, validator: defaultClaimNoticeValidator(), clock: clock, journal: [])
    }
}
