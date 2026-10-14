import AcmePlatform
import Foundation

extension Referrals {
    /// Moves default closure requests through their life cycle and keeps a journal of what it did.
    final class DefaultClosureRequestDesk {
        var store: any DefaultClosureRequestStore
        var validator: DefaultClosureRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DefaultClosureRequestStore, validator: DefaultClosureRequestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("default closure request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultClosureRequestStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default closure request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultClosureRequestStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newDefaultClosureRequestDesk(_ store: any DefaultClosureRequestStore, clock: any Kit.Clocks.Clock) -> DefaultClosureRequestDesk {
        return DefaultClosureRequestDesk(
            store: store,
            validator: defaultDefaultClosureRequestValidator(),
            clock: clock,
            journal: []
        )
    }
}
