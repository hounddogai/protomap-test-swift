import AcmePlatform
import Foundation

extension Labs {
    /// Moves global panel templates through their life cycle and keeps a journal of what it did.
    final class GlobalPanelTemplateCoordinator {
        var store: any GlobalPanelTemplateStore
        var validator: GlobalPanelTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalPanelTemplateEngine

        init(store: any GlobalPanelTemplateStore, validator: GlobalPanelTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalPanelTemplateEngine) {
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
                throw Kit.Failure("global panel template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalPanelTemplateStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global panel template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalPanelTemplateStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global panel template \(code) not found")
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

    static func newGlobalPanelTemplateCoordinator(_ store: any GlobalPanelTemplateStore, clock: any Kit.Clocks.Clock) -> GlobalPanelTemplateCoordinator {
        return GlobalPanelTemplateCoordinator(
            store: store,
            validator: defaultGlobalPanelTemplateValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalPanelTemplateEngine()
        )
    }
}
