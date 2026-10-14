import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves interaction overrides through their life cycle and keeps a journal of what it did.
    final class InteractionOverrideService {
        var store: any InteractionOverrideStore
        var validator: InteractionOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: InteractionOverrideEngine

        init(store: any InteractionOverrideStore, validator: InteractionOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: InteractionOverrideEngine) {
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
                throw Kit.Failure("interaction override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(InteractionOverrideStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("interaction override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(InteractionOverrideStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("interaction override \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newInteractionOverrideService(_ store: any InteractionOverrideStore, clock: any Kit.Clocks.Clock) -> InteractionOverrideService {
        return InteractionOverrideService(
            store: store,
            validator: defaultInteractionOverrideValidator(),
            clock: clock,
            journal: [],
            engine: defaultInteractionOverrideEngine()
        )
    }
}
