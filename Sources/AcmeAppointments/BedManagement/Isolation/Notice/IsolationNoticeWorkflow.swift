import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves isolation notices through their life cycle and keeps a journal of what it did.
    final class IsolationNoticeManager {
        var store: any IsolationNoticeStore
        var validator: IsolationNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any IsolationNoticeStore, validator: IsolationNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("isolation notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(IsolationNoticeStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("isolation notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(IsolationNoticeStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newIsolationNoticeManager(_ store: any IsolationNoticeStore, clock: any Kit.Clocks.Clock) -> IsolationNoticeManager {
        return IsolationNoticeManager(
            store: store,
            validator: defaultIsolationNoticeValidator(),
            clock: clock,
            journal: []
        )
    }
}
