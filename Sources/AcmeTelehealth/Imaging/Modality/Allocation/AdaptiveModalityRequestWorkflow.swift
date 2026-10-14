import AcmePlatform
import Foundation

extension Imaging {
    /// Moves adaptive modality requests through their life cycle and keeps a journal of what it did.
    final class AdaptiveModalityRequestCoordinator {
        var store: any AdaptiveModalityRequestStore
        var validator: AdaptiveModalityRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AdaptiveModalityRequestEngine

        init(store: any AdaptiveModalityRequestStore, validator: AdaptiveModalityRequestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AdaptiveModalityRequestEngine) {
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
                throw Kit.Failure("adaptive modality request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveModalityRequestStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive modality request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveModalityRequestStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive modality request \(code) not found")
            }
            let result = engine.price(item)
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

    static func newAdaptiveModalityRequestCoordinator(_ store: any AdaptiveModalityRequestStore, clock: any Kit.Clocks.Clock) -> AdaptiveModalityRequestCoordinator {
        return AdaptiveModalityRequestCoordinator(
            store: store,
            validator: defaultAdaptiveModalityRequestValidator(),
            clock: clock,
            journal: [],
            engine: defaultAdaptiveModalityRequestEngine()
        )
    }
}
