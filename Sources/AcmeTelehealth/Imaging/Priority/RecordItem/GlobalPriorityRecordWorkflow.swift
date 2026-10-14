import AcmePlatform
import Foundation

extension Imaging {
    /// Moves global priority records through their life cycle and keeps a journal of what it did.
    final class GlobalPriorityRecordDesk {
        var store: any GlobalPriorityRecordStore
        var validator: GlobalPriorityRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any GlobalPriorityRecordStore, validator: GlobalPriorityRecordValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("global priority record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalPriorityRecordStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global priority record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalPriorityRecordStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newGlobalPriorityRecordDesk(_ store: any GlobalPriorityRecordStore, clock: any Kit.Clocks.Clock) -> GlobalPriorityRecordDesk {
        return GlobalPriorityRecordDesk(
            store: store,
            validator: defaultGlobalPriorityRecordValidator(),
            clock: clock,
            journal: []
        )
    }
}
