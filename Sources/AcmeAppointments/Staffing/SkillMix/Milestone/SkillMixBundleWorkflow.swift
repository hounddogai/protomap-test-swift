import AcmePlatform
import Foundation

extension Staffing {
    /// Moves skill mix bundles through their life cycle and keeps a journal of what it did.
    final class SkillMixBundleCoordinator {
        var store: any SkillMixBundleStore
        var validator: SkillMixBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SkillMixBundleEngine

        init(store: any SkillMixBundleStore, validator: SkillMixBundleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SkillMixBundleEngine) {
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
                throw Kit.Failure("skill mix bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SkillMixBundleStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("skill mix bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SkillMixBundleStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("skill mix bundle \(code) not found")
            }
            let result = engine.run(item)
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

    static func newSkillMixBundleCoordinator(_ store: any SkillMixBundleStore, clock: any Kit.Clocks.Clock) -> SkillMixBundleCoordinator {
        return SkillMixBundleCoordinator(
            store: store,
            validator: defaultSkillMixBundleValidator(),
            clock: clock,
            journal: [],
            engine: defaultSkillMixBundleEngine()
        )
    }
}
