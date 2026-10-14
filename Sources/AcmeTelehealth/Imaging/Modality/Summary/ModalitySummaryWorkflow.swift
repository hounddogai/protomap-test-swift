import AcmePlatform
import Foundation

extension Imaging {
    /// Moves modality summaries through their life cycle and keeps a journal of what it did.
    final class ModalitySummaryManager {
        var store: any ModalitySummaryStore
        var validator: ModalitySummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ModalitySummaryEngine

        init(store: any ModalitySummaryStore, validator: ModalitySummaryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ModalitySummaryEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("modality summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ModalitySummaryStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("modality summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ModalitySummaryStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("modality summary \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newModalitySummaryManager(_ store: any ModalitySummaryStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ModalitySummaryManager {
        return ModalitySummaryManager(
            store: store,
            validator: defaultModalitySummaryValidator(),
            clock: clock,
            journal: [],
            engine: defaultModalitySummaryEngine(flags)
        )
    }
}
