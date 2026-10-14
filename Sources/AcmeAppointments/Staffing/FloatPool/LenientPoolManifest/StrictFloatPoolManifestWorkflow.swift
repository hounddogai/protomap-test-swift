import AcmePlatform
import Foundation

extension Staffing {
    /// Moves strict float pool manifests through their life cycle and keeps a journal of what it did.
    final class StrictFloatPoolManifestCoordinator {
        var store: any StrictFloatPoolManifestStore
        var validator: StrictFloatPoolManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StrictFloatPoolManifestStore, validator: StrictFloatPoolManifestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict float pool manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictFloatPoolManifestStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict float pool manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictFloatPoolManifestStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newStrictFloatPoolManifestCoordinator(_ store: any StrictFloatPoolManifestStore, clock: any Kit.Clocks.Clock) -> StrictFloatPoolManifestCoordinator {
        return StrictFloatPoolManifestCoordinator(
            store: store,
            validator: defaultStrictFloatPoolManifestValidator(),
            clock: clock,
            journal: []
        )
    }
}
