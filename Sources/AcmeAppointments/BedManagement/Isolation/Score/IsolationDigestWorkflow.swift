import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves isolation digests through their life cycle and keeps a journal of what it did.
    final class IsolationDigestDesk {
        var store: any IsolationDigestStore
        var validator: IsolationDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any IsolationDigestStore, validator: IsolationDigestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("isolation digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(IsolationDigestStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("isolation digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(IsolationDigestStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newIsolationDigestDesk(_ store: any IsolationDigestStore, clock: any Kit.Clocks.Clock) -> IsolationDigestDesk {
        return IsolationDigestDesk(
            store: store,
            validator: defaultIsolationDigestValidator(),
            clock: clock,
            journal: []
        )
    }
}
