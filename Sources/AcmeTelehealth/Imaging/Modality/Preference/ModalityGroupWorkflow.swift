import AcmePlatform
import Foundation

extension Imaging {
    /// Moves modality groups through their life cycle and keeps a journal of what it did.
    final class ModalityGroupManager {
        var store: any ModalityGroupStore
        var validator: ModalityGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ModalityGroupEngine

        init(store: any ModalityGroupStore, validator: ModalityGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ModalityGroupEngine) {
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
                throw Kit.Failure("modality group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ModalityGroupStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("modality group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ModalityGroupStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("modality group \(code) not found")
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

    static func newModalityGroupManager(_ store: any ModalityGroupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ModalityGroupManager {
        return ModalityGroupManager(
            store: store,
            validator: defaultModalityGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultModalityGroupEngine(flags)
        )
    }
}
