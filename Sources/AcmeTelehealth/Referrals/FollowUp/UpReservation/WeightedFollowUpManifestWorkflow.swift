import AcmePlatform
import Foundation

extension Referrals {
    /// Moves weighted follow up manifests through their life cycle and keeps a journal of what it did.
    final class WeightedFollowUpManifestCoordinator {
        var store: any WeightedFollowUpManifestStore
        var validator: WeightedFollowUpManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedFollowUpManifestEngine

        init(store: any WeightedFollowUpManifestStore, validator: WeightedFollowUpManifestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedFollowUpManifestEngine) {
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
                throw Kit.Failure("weighted follow up manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedFollowUpManifestStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted follow up manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedFollowUpManifestStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted follow up manifest \(code) not found")
            }
            let result = engine.price(item)
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

    static func newWeightedFollowUpManifestCoordinator(_ store: any WeightedFollowUpManifestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> WeightedFollowUpManifestCoordinator {
        return WeightedFollowUpManifestCoordinator(
            store: store,
            validator: defaultWeightedFollowUpManifestValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedFollowUpManifestEngine(flags)
        )
    }
}
