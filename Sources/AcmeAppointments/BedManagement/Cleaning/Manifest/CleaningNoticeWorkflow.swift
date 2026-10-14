import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves cleaning notices through their life cycle and keeps a journal of what it did.
    final class CleaningNoticeService {
        var store: any CleaningNoticeStore
        var validator: CleaningNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CleaningNoticeStore, validator: CleaningNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("cleaning notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CleaningNoticeStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("cleaning notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CleaningNoticeStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newCleaningNoticeService(_ store: any CleaningNoticeStore, clock: any Kit.Clocks.Clock) -> CleaningNoticeService {
        return CleaningNoticeService(
            store: store,
            validator: defaultCleaningNoticeValidator(),
            clock: clock,
            journal: []
        )
    }
}
