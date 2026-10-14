import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves default authorization targets through their life cycle and keeps a journal of what it did.
    final class DefaultAuthorizationTargetCoordinator {
        var store: any DefaultAuthorizationTargetStore
        var validator: DefaultAuthorizationTargetValidatorExtra
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultAuthorizationTargetEngine

        init(store: any DefaultAuthorizationTargetStore, validator: DefaultAuthorizationTargetValidatorExtra, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultAuthorizationTargetEngine) {
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
                throw Kit.Failure("default authorization target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultAuthorizationTargetStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default authorization target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultAuthorizationTargetStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default authorization target \(code) not found")
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

    static func newDefaultAuthorizationTargetCoordinator(_ store: any DefaultAuthorizationTargetStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> DefaultAuthorizationTargetCoordinator {
        return DefaultAuthorizationTargetCoordinator(
            store: store,
            validator: defaultDefaultAuthorizationTargetValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultAuthorizationTargetEngine(flags)
        )
    }
}
