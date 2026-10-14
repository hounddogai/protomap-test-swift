import AcmePlatform
import Foundation

extension Labs {
    /// Moves scheduled accession notices through their life cycle and keeps a journal of what it did.
    final class ScheduledAccessionNoticeDesk {
        var store: any ScheduledAccessionNoticeStore
        var validator: ScheduledAccessionNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledAccessionNoticeEngine

        init(store: any ScheduledAccessionNoticeStore, validator: ScheduledAccessionNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledAccessionNoticeEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled accession notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledAccessionNoticeStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled accession notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledAccessionNoticeStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled accession notice \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newScheduledAccessionNoticeDesk(_ store: any ScheduledAccessionNoticeStore, clock: any Kit.Clocks.Clock) -> ScheduledAccessionNoticeDesk {
        return ScheduledAccessionNoticeDesk(
            store: store,
            validator: defaultScheduledAccessionNoticeValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledAccessionNoticeEngine()
        )
    }
}
