import AcmePlatform
import Foundation

extension Imaging {
    /// Moves capped modality requests through their life cycle and keeps a journal of what it did.
    final class CappedModalityRequestCoordinator {
        var store: any CappedModalityRequestStore
        var validator: CappedModalityRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedModalityRequestEngine

        init(store: any CappedModalityRequestStore, validator: CappedModalityRequestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedModalityRequestEngine) {
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
                throw Kit.Failure("capped modality request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedModalityRequestStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped modality request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedModalityRequestStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped modality request \(code) not found")
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

    static func newCappedModalityRequestCoordinator(_ store: any CappedModalityRequestStore, clock: any Kit.Clocks.Clock) -> CappedModalityRequestCoordinator {
        return CappedModalityRequestCoordinator(
            store: store,
            validator: defaultCappedModalityRequestValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedModalityRequestEngine()
        )
    }
}
