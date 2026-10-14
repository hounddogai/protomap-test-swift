import AcmePlatform
import Foundation

extension Labs {
    /// Moves fallback specimen requests through their life cycle and keeps a journal of what it did.
    final class FallbackSpecimenRequestManager {
        var store: any FallbackSpecimenRequestStore
        var validator: FallbackSpecimenRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackSpecimenRequestEngine

        init(store: any FallbackSpecimenRequestStore, validator: FallbackSpecimenRequestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackSpecimenRequestEngine) {
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
                throw Kit.Failure("fallback specimen request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackSpecimenRequestStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback specimen request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackSpecimenRequestStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback specimen request \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newFallbackSpecimenRequestManager(_ store: any FallbackSpecimenRequestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FallbackSpecimenRequestManager {
        return FallbackSpecimenRequestManager(
            store: store,
            validator: defaultFallbackSpecimenRequestValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackSpecimenRequestEngine(flags)
        )
    }
}
