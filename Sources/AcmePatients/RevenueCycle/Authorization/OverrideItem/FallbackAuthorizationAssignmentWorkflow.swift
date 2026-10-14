import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves fallback authorization assignments through their life cycle and keeps a journal of what it did.
    final class FallbackAuthorizationAssignmentService {
        var store: any FallbackAuthorizationAssignmentStore
        var validator: FallbackAuthorizationAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackAuthorizationAssignmentEngine

        init(store: any FallbackAuthorizationAssignmentStore, validator: FallbackAuthorizationAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackAuthorizationAssignmentEngine) {
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
                throw Kit.Failure("fallback authorization assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackAuthorizationAssignmentStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback authorization assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackAuthorizationAssignmentStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback authorization assignment \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newFallbackAuthorizationAssignmentService(_ store: any FallbackAuthorizationAssignmentStore, clock: any Kit.Clocks.Clock) -> FallbackAuthorizationAssignmentService {
        return FallbackAuthorizationAssignmentService(
            store: store,
            validator: defaultFallbackAuthorizationAssignmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackAuthorizationAssignmentEngine()
        )
    }
}
