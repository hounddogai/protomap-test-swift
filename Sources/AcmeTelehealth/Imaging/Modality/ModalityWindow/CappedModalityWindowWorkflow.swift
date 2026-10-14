import AcmePlatform
import Foundation

extension Imaging {
    /// Moves capped modality windows through their life cycle and keeps a journal of what it did.
    final class CappedModalityWindowWorkflow {
        var store: any CappedModalityWindowStore
        var validator: CappedModalityWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CappedModalityWindowStore, validator: CappedModalityWindowValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped modality window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedModalityWindowStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped modality window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedModalityWindowStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newCappedModalityWindowWorkflow(_ store: any CappedModalityWindowStore, clock: any Kit.Clocks.Clock) -> CappedModalityWindowWorkflow {
        return CappedModalityWindowWorkflow(
            store: store,
            validator: defaultCappedModalityWindowValidator(),
            clock: clock,
            journal: []
        )
    }
}
