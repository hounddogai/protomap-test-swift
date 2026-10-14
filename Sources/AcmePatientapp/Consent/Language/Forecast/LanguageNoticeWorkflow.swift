import AcmePlatform
import Foundation

extension Consent {
    /// Moves language notices through their life cycle and keeps a journal of what it did.
    final class LanguageNoticeService {
        var store: any LanguageNoticeStore
        var validator: LanguageNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LanguageNoticeStore, validator: LanguageNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("language notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LanguageNoticeStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("language notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LanguageNoticeStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newLanguageNoticeService(_ store: any LanguageNoticeStore, clock: any Kit.Clocks.Clock) -> LanguageNoticeService {
        return LanguageNoticeService(
            store: store,
            validator: defaultLanguageNoticeValidator(),
            clock: clock,
            journal: []
        )
    }
}
