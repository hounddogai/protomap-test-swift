import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves remittance notices through their life cycle and keeps a journal of what it did.
    final class RemittanceNoticeService {
        var store: any RemittanceNoticeStore
        var validator: RemittanceNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RemittanceNoticeStore, validator: RemittanceNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("remittance notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RemittanceNoticeStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RemittanceNoticeStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newRemittanceNoticeService(_ store: any RemittanceNoticeStore, clock: any Kit.Clocks.Clock) -> RemittanceNoticeService {
        return RemittanceNoticeService(
            store: store,
            validator: defaultRemittanceNoticeValidator(),
            clock: clock,
            journal: []
        )
    }
}
