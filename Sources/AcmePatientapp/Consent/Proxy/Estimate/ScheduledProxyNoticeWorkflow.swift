import AcmePlatform
import Foundation

extension Consent {
    /// Moves scheduled proxy notices through their life cycle and keeps a journal of what it did.
    final class ScheduledProxyNoticeService {
        var store: any ScheduledProxyNoticeStore
        var validator: ScheduledProxyNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ScheduledProxyNoticeStore, validator: ScheduledProxyNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("scheduled proxy notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledProxyNoticeStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled proxy notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledProxyNoticeStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newScheduledProxyNoticeService(_ store: any ScheduledProxyNoticeStore, clock: any Kit.Clocks.Clock) -> ScheduledProxyNoticeService {
        return ScheduledProxyNoticeService(
            store: store,
            validator: defaultScheduledProxyNoticeValidator(),
            clock: clock,
            journal: []
        )
    }
}
