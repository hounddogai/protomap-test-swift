import AcmePlatform
import Foundation

extension Referrals {
    /// Moves follow up overrides through their life cycle and keeps a journal of what it did.
    final class FollowUpOverrideCoordinator {
        var store: any FollowUpOverrideStore
        var validator: FollowUpOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FollowUpOverrideEngine

        init(store: any FollowUpOverrideStore, validator: FollowUpOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FollowUpOverrideEngine) {
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
                throw Kit.Failure("follow up override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FollowUpOverrideStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FollowUpOverrideStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up override \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newFollowUpOverrideCoordinator(_ store: any FollowUpOverrideStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FollowUpOverrideCoordinator {
        return FollowUpOverrideCoordinator(
            store: store,
            validator: defaultFollowUpOverrideValidator(),
            clock: clock,
            journal: [],
            engine: defaultFollowUpOverrideEngine(flags)
        )
    }
}
