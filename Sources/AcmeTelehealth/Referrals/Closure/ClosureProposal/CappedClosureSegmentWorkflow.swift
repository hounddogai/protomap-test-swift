import AcmePlatform
import Foundation

extension Referrals {
    /// Moves capped closure segments through their life cycle and keeps a journal of what it did.
    final class CappedClosureSegmentDesk {
        var store: any CappedClosureSegmentStore
        var validator: CappedClosureSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CappedClosureSegmentStore, validator: CappedClosureSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("capped closure segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedClosureSegmentStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped closure segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedClosureSegmentStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newCappedClosureSegmentDesk(_ store: any CappedClosureSegmentStore, clock: any Kit.Clocks.Clock) -> CappedClosureSegmentDesk {
        return CappedClosureSegmentDesk(
            store: store,
            validator: defaultCappedClosureSegmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
