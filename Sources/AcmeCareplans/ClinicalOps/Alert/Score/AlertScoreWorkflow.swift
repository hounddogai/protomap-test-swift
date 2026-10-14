import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves alert scores through their life cycle and keeps a journal of what it did.
    final class AlertScoreDesk {
        var store: any AlertScoreStore
        var validator: AlertScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AlertScoreStore, validator: AlertScoreValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("alert score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AlertScoreStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AlertScoreStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newAlertScoreDesk(_ store: any AlertScoreStore, clock: any Kit.Clocks.Clock) -> AlertScoreDesk {
        return AlertScoreDesk(store: store, validator: defaultAlertScoreValidator(), clock: clock, journal: [])
    }
}
