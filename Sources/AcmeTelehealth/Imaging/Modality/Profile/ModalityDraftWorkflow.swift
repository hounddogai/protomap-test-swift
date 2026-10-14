import AcmePlatform
import Foundation

extension Imaging {
    /// Moves modality drafts through their life cycle and keeps a journal of what it did.
    final class ModalityDraftService {
        var store: any ModalityDraftStore
        var validator: ModalityDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ModalityDraftEngine

        init(store: any ModalityDraftStore, validator: ModalityDraftValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ModalityDraftEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("modality draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ModalityDraftStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("modality draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ModalityDraftStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("modality draft \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newModalityDraftService(_ store: any ModalityDraftStore, clock: any Kit.Clocks.Clock) -> ModalityDraftService {
        return ModalityDraftService(
            store: store,
            validator: defaultModalityDraftValidator(),
            clock: clock,
            journal: [],
            engine: defaultModalityDraftEngine()
        )
    }
}
