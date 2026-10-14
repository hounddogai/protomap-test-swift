import AcmePlatform
import Foundation

extension Referrals {
    /// Moves manual network notices through their life cycle and keeps a journal of what it did.
    final class ManualNetworkNoticeDesk {
        var store: any ManualNetworkNoticeStore
        var validator: ManualNetworkNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ManualNetworkNoticeStore, validator: ManualNetworkNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("manual network notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualNetworkNoticeStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual network notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualNetworkNoticeStatus.closed)
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

    static func newManualNetworkNoticeDesk(_ store: any ManualNetworkNoticeStore, clock: any Kit.Clocks.Clock) -> ManualNetworkNoticeDesk {
        return ManualNetworkNoticeDesk(
            store: store,
            validator: defaultManualNetworkNoticeValidator(),
            clock: clock,
            journal: []
        )
    }
}
