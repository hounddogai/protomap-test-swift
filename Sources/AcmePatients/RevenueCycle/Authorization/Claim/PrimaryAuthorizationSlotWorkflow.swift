import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves primary authorization slots through their life cycle and keeps a journal of what it did.
    final class PrimaryAuthorizationSlotService {
        var store: any PrimaryAuthorizationSlotStore
        var validator: PrimaryAuthorizationSlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryAuthorizationSlotEngine

        init(store: any PrimaryAuthorizationSlotStore, validator: PrimaryAuthorizationSlotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryAuthorizationSlotEngine) {
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
                throw Kit.Failure("primary authorization slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryAuthorizationSlotStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary authorization slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryAuthorizationSlotStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary authorization slot \(code) not found")
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

    static func newPrimaryAuthorizationSlotService(_ store: any PrimaryAuthorizationSlotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PrimaryAuthorizationSlotService {
        return PrimaryAuthorizationSlotService(
            store: store,
            validator: defaultPrimaryAuthorizationSlotValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryAuthorizationSlotEngine(flags)
        )
    }
}
