import AcmePlatform
import Foundation

extension Imaging {
    /// Moves modality metrics through their life cycle and keeps a journal of what it did.
    final class ModalityMetricDesk {
        var store: any ModalityMetricStore
        var validator: ModalityMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ModalityMetricEngine

        init(store: any ModalityMetricStore, validator: ModalityMetricValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ModalityMetricEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("modality metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ModalityMetricStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("modality metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ModalityMetricStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("modality metric \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newModalityMetricDesk(_ store: any ModalityMetricStore, clock: any Kit.Clocks.Clock) -> ModalityMetricDesk {
        return ModalityMetricDesk(
            store: store,
            validator: defaultModalityMetricValidator(),
            clock: clock,
            journal: [],
            engine: defaultModalityMetricEngine()
        )
    }
}
