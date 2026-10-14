import AcmePlatform
import Foundation

extension Imaging {
    /// Moves scheduled modality scores through their life cycle and keeps a journal of what it did.
    final class ScheduledModalityScoreManager {
        var store: any ScheduledModalityScoreStore
        var validator: ScheduledModalityScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ScheduledModalityScoreStore, validator: ScheduledModalityScoreValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("scheduled modality score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledModalityScoreStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled modality score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledModalityScoreStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newScheduledModalityScoreManager(_ store: any ScheduledModalityScoreStore, clock: any Kit.Clocks.Clock) -> ScheduledModalityScoreManager {
        return ScheduledModalityScoreManager(
            store: store,
            validator: defaultScheduledModalityScoreValidator(),
            clock: clock,
            journal: []
        )
    }
}
