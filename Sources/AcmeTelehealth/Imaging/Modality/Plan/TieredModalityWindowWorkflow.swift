import AcmePlatform
import Foundation

extension Imaging {
    /// Moves tiered modality windows through their life cycle and keeps a journal of what it did.
    final class TieredModalityWindowCoordinator {
        var store: any TieredModalityWindowStore
        var validator: TieredModalityWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any TieredModalityWindowStore, validator: TieredModalityWindowValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("tiered modality window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredModalityWindowStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered modality window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredModalityWindowStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newTieredModalityWindowCoordinator(_ store: any TieredModalityWindowStore, clock: any Kit.Clocks.Clock) -> TieredModalityWindowCoordinator {
        return TieredModalityWindowCoordinator(
            store: store,
            validator: defaultTieredModalityWindowValidator(),
            clock: clock,
            journal: []
        )
    }
}
